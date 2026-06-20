import 'dart:collection';

import 'package:flutter/foundation.dart';

class DocumentReaderController extends ChangeNotifier {
  final List<List<String>> _pages;
  int _currentPageIndex;

  DocumentReaderController({
    required List<List<String>> pages,
    int initialPageIndex = 0,
  })  : _pages = pages.isEmpty
            ? <List<String>>[
                <String>['No content available.']
              ]
            : List<List<String>>.unmodifiable(
                pages
                    .map((page) => List<String>.unmodifiable(page))
                    .toList(growable: false),
              ),
        _currentPageIndex = 0 {
    _currentPageIndex = initialPageIndex.clamp(0, _pages.length - 1).toInt();
  }

  UnmodifiableListView<String> get currentParagraphs {
    return UnmodifiableListView<String>(_pages[_currentPageIndex]);
  }

  int get currentPageNumber => _currentPageIndex + 1;
  int get totalPages => _pages.length;
  bool get canGoPrevious => _currentPageIndex > 0;
  bool get canGoNext => _currentPageIndex < _pages.length - 1;
  bool get isLastPage => _currentPageIndex == _pages.length - 1;

  void goNext() {
    if (!canGoNext) {
      return;
    }
    _currentPageIndex += 1;
    notifyListeners();
  }

  void goPrevious() {
    if (!canGoPrevious) {
      return;
    }
    _currentPageIndex -= 1;
    notifyListeners();
  }

  void jumpToPage(int pageNumber) {
    if (_pages.isEmpty) {
      return;
    }
    final int index = (pageNumber - 1).clamp(0, _pages.length - 1).toInt();
    if (index == _currentPageIndex) {
      return;
    }
    _currentPageIndex = index;
    notifyListeners();
  }
}
