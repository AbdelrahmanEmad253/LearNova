"""Provider chain for level grading and backend AI scoring.

Design goals:
- No single provider should be a point of failure.
- Support OpenAI-compatible providers including NaraRouter, OpenRouter, Groq,
  GitHub Models, and xAI.
- Expose a safe provider_status() snapshot for /health without leaking keys.
"""
from __future__ import annotations

import json
import logging
import os
import re
from dataclasses import dataclass
from typing import Any, Dict, Optional

import requests

logger = logging.getLogger(__name__)


@dataclass
class ProviderResult:
    provider: str
    model: str
    text: str


class ProviderChainError(RuntimeError):
    def __init__(self, errors: list[str]):
        message = "AI provider chain unavailable: " + " | ".join(errors)
        super().__init__(message)
        self.errors = errors


def _env_int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, str(default)))
    except ValueError:
        return default


def _env_float(name: str, default: float) -> float:
    try:
        return float(os.getenv(name, str(default)))
    except ValueError:
        return default


TIMEOUT = _env_int("AI_PROVIDER_TIMEOUT_SECONDS", 35)
MAX_TOKENS = _env_int("AI_PROVIDER_MAX_TOKENS", 1800)
TEMPERATURE = _env_float("AI_PROVIDER_TEMPERATURE", 0.0)


def provider_order() -> list[str]:
    raw = os.getenv("AI_PROVIDER_ORDER", "nararouter,groq,gemini,openrouter,github,xai")
    providers: list[str] = []

    for item in raw.split(","):
        provider = item.strip().lower()
        if not provider:
            continue

        if provider == "grok":
            provider = "xai"

        if provider not in providers:
            providers.append(provider)

    return providers


def _has_env(*names: str) -> bool:
    return any(bool(os.getenv(name)) for name in names)


def provider_status() -> dict[str, Any]:
    """Safe debug snapshot for /health. Does not expose API keys."""
    return {
        "provider_order": provider_order(),
        "configured": {
            "nararouter": _has_env("NARAROUTER_API_KEY"),
            "groq": _has_env("GROQ_API_KEY"),
            "gemini": _has_env("GEMINI_API_KEY"),
            "openrouter": _has_env("OPENROUTER_API_KEY"),
            "github": _has_env("GITHUB_MODELS_API_KEY", "GITHUB_TOKEN"),
            "xai": _has_env("XAI_API_KEY", "GROK_API_KEY"),
            "generic_openai_compatible": _has_env("AI_API_KEY") and bool(os.getenv("AI_BASE_URL")) and bool(os.getenv("AI_MODEL")),
        },
        "models": {
            "nararouter": os.getenv("NARAROUTER_GRADER_MODEL") or os.getenv("NARAROUTER_MODEL"),
            "groq": os.getenv("GROQ_MODEL"),
            "gemini": os.getenv("GEMINI_MODEL"),
            "openrouter": os.getenv("OPENROUTER_MODEL"),
            "github": os.getenv("GITHUB_MODEL"),
            "xai": os.getenv("XAI_MODEL") or os.getenv("GROK_MODEL"),
            "generic": os.getenv("AI_MODEL"),
        },
        "timeout_seconds": TIMEOUT,
        "max_tokens": MAX_TOKENS,
        "temperature": TEMPERATURE,
    }


def generate_text(system_prompt: str, user_prompt: str, *, json_schema: Optional[dict] = None) -> ProviderResult:
    errors: list[str] = []

    for provider in provider_order():
        try:
            if provider in {"primary", "generic"}:
                return _call_openai_compatible(
                    provider="generic",
                    base_url=os.getenv("AI_BASE_URL", ""),
                    api_key=os.getenv("AI_API_KEY"),
                    model=os.getenv("AI_MODEL", ""),
                    system_prompt=system_prompt,
                    user_prompt=user_prompt,
                    json_schema=json_schema,
                )

            if provider == "nararouter":
                return _call_openai_compatible(
                    provider="nararouter",
                    base_url=os.getenv("NARAROUTER_BASE_URL", "https://router.naraya.ai/v1"),
                    api_key=os.getenv("NARAROUTER_API_KEY"),
                    model=os.getenv("NARAROUTER_GRADER_MODEL") or os.getenv("NARAROUTER_MODEL", "claude-sonnet-4.5"),
                    system_prompt=system_prompt,
                    user_prompt=user_prompt,
                    json_schema=json_schema,
                )

            if provider == "groq":
                return _call_openai_compatible(
                    provider="groq",
                    base_url="https://api.groq.com/openai/v1",
                    api_key=os.getenv("GROQ_API_KEY"),
                    model=os.getenv("GROQ_MODEL", "llama-3.3-70b-versatile"),
                    system_prompt=system_prompt,
                    user_prompt=user_prompt,
                    json_schema=json_schema,
                )

            if provider == "openrouter":
                return _call_openai_compatible(
                    provider="openrouter",
                    base_url="https://openrouter.ai/api/v1",
                    api_key=os.getenv("OPENROUTER_API_KEY"),
                    model=os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3.3-70b-instruct:free"),
                    system_prompt=system_prompt,
                    user_prompt=user_prompt,
                    json_schema=json_schema,
                    extra_headers={
                        "HTTP-Referer": os.getenv("OPENROUTER_SITE_URL", "https://learnova.local"),
                        "X-Title": os.getenv("OPENROUTER_APP_NAME", "LearNova ML-AI"),
                    },
                )

            if provider == "github":
                return _call_openai_compatible(
                    provider="github",
                    base_url=os.getenv("GITHUB_MODELS_BASE_URL", "https://models.github.ai/inference"),
                    api_key=os.getenv("GITHUB_MODELS_API_KEY") or os.getenv("GITHUB_TOKEN"),
                    model=os.getenv("GITHUB_MODEL", "openai/gpt-5-mini"),
                    system_prompt=system_prompt,
                    user_prompt=user_prompt,
                    json_schema=json_schema,
                )

            if provider == "xai":
                return _call_openai_compatible(
                    provider="xai",
                    base_url=os.getenv("XAI_API_URL", "https://api.x.ai/v1"),
                    api_key=os.getenv("XAI_API_KEY") or os.getenv("GROK_API_KEY"),
                    model=os.getenv("XAI_MODEL") or os.getenv("GROK_MODEL", "grok-3-mini"),
                    system_prompt=system_prompt,
                    user_prompt=user_prompt,
                    json_schema=json_schema,
                )

            if provider == "gemini":
                return _call_gemini(system_prompt, user_prompt, json_schema=json_schema)

            errors.append(f"{provider}: unsupported provider")
        except Exception as exc:
            logger.warning("Provider %s failed: %s", provider, exc)
            errors.append(f"{provider}: {exc}")

    raise ProviderChainError(errors or ["No providers configured"])


def _call_openai_compatible(
    *,
    provider: str,
    base_url: str,
    api_key: Optional[str],
    model: str,
    system_prompt: str,
    user_prompt: str,
    json_schema: Optional[dict],
    extra_headers: Optional[dict[str, str]] = None,
) -> ProviderResult:
    if not base_url:
        raise RuntimeError(f"missing base URL for {provider}")

    if not api_key:
        raise RuntimeError(f"missing API key for {provider}")

    if not model:
        raise RuntimeError(f"missing model for {provider}")

    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    if extra_headers:
        headers.update(extra_headers)

    payload: Dict[str, Any] = {
        "model": model,
        "temperature": TEMPERATURE,
        "max_tokens": MAX_TOKENS,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }

    # Some OpenAI-compatible gateways do not support strict response_format.
    # Keep it enabled by default but allow disabling from Railway env.
    use_response_format = os.getenv(f"{provider.upper()}_USE_RESPONSE_FORMAT", os.getenv("AI_USE_RESPONSE_FORMAT", "true")).lower() != "false"

    if json_schema and use_response_format:
        payload["response_format"] = {
            "type": "json_schema",
            "json_schema": {
                "name": "learnova_response",
                "schema": json_schema,
                "strict": True,
            },
        }

    url = f"{base_url.rstrip('/')}/chat/completions"

    resp = requests.post(url, headers=headers, json=payload, timeout=TIMEOUT)

    if resp.status_code >= 400:
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:700]}")

    data = resp.json()
    text = data["choices"][0]["message"].get("content") or ""

    if not text.strip():
        raise RuntimeError("empty response")

    return ProviderResult(provider=provider, model=model, text=text)


def _call_gemini(system_prompt: str, user_prompt: str, *, json_schema: Optional[dict]) -> ProviderResult:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("missing GEMINI_API_KEY")

    model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"

    payload: Dict[str, Any] = {
        "systemInstruction": {"parts": [{"text": system_prompt}]},
        "contents": [{"role": "user", "parts": [{"text": user_prompt}]}],
        "generationConfig": {
            "temperature": TEMPERATURE,
            "maxOutputTokens": MAX_TOKENS,
        },
    }

    if json_schema:
        payload["generationConfig"].update(
            {
                "responseMimeType": "application/json",
                "responseSchema": json_schema,
            }
        )

    resp = requests.post(f"{url}?key={api_key}", json=payload, timeout=TIMEOUT)

    if resp.status_code >= 400:
        raise RuntimeError(f"HTTP {resp.status_code}: {resp.text[:700]}")

    data = resp.json()
    text = data["candidates"][0]["content"]["parts"][0].get("text") or ""

    if not text.strip():
        raise RuntimeError("empty response")

    return ProviderResult(provider="gemini", model=model, text=text)


def parse_json_object(text: str) -> dict[str, Any]:
    cleaned = text.strip()

    if cleaned.startswith("```"):
        cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
        cleaned = re.sub(r"\s*```$", "", cleaned)

    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        start, end = cleaned.find("{"), cleaned.rfind("}")

        if start != -1 and end != -1 and end > start:
            return json.loads(cleaned[start : end + 1])

        raise
