import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:gitjournal/note.dart';
import 'package:gitjournal/utils.dart';
import 'package:gitjournal/apis/git.dart';
import 'package:gitjournal/screens/journal_editor.dart';
import 'package:gitjournal/screens/journal_browsing.dart';
import 'package:gitjournal/state_container.dart';
import 'package:gitjournal/widgets/app_drawer.dart';
import 'package:gitjournal/widgets/journal_list.dart';
import 'package:gitjournal/themes.dart';

class JournalListingScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<Note> allNotes;

  JournalListingScreen(this.allNotes);

  @override
  Widget build(BuildContext context) {
    final container = StateContainer.of(context);
    final appState = container.appState;

    var createButton = FloatingActionButton(
      key: const ValueKey("FAB"),
      onPressed: () => _newPost(context),
      child: Icon(Icons.add),
    );

    Widget journalList = JournalList(
      notes: allNotes,
      noteSelectedFunction: (noteIndex) {
        var route = MaterialPageRoute(
          builder: (context) => JournalBrowsingScreen(
            notes: allNotes,
            noteIndex: noteIndex,
          ),
        );
        Navigator.of(context).push(route);
      },
      emptyText: "Why not add your first\n Journal Entry?",
    );

    bool shouldShowBadge =
        !appState.remoteGitRepoConfigured && appState.hasJournalEntries;
    var appBarMenuButton = BadgeIconButton(
      key: const ValueKey("DrawerButton"),
      icon: const Icon(Icons.menu),
      itemCount: shouldShowBadge ? 1 : 0,
      onPressed: () {
        _scaffoldKey.currentState.openDrawer();
      },
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('GitJournal'),
        leading: appBarMenuButton,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearch(allNotes),
              );
            },
          )
        ],
      ),
      floatingActionButton: createButton,
      body: Center(
        child: RefreshIndicator(
            child: journalList,
            onRefresh: () async {
              try {
                await container.syncNotes();
              } on GitException catch (exp) {
                showSnackbar(context, exp.cause);
              }
            }),
      ),
      drawer: AppDrawer(),
    );
  }

  void _newPost(BuildContext context) {
    var route = MaterialPageRoute(builder: (context) => JournalEditor());
    Navigator.of(context).push(route);
  }
}

class NoteSearch extends SearchDelegate<Note> {
  final List<Note> notes;

  NoteSearch(this.notes);

  // Workaround because of https://github.com/flutter/flutter/issues/32180
  @override
  ThemeData appBarTheme(BuildContext context) {
    var theme = Theme.of(context);
    if (theme.brightness == Brightness.light) {
      return theme;
    }

    return theme.copyWith(
      primaryColor: Themes.dark.primaryColor,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildJournalList(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildJournalList(context, query);
  }

  JournalList buildJournalList(BuildContext context, String query) {
    // TODO: This should be made far more efficient
    var q = query.toLowerCase();
    var filteredNotes = notes.where((note) {
      return note.body.toLowerCase().contains(q);
    }).toList();

    Widget journalList = JournalList(
      notes: filteredNotes,
      noteSelectedFunction: (noteIndex) {
        var route = MaterialPageRoute(
          builder: (context) => JournalBrowsingScreen(
            notes: filteredNotes,
            noteIndex: noteIndex,
          ),
        );
        Navigator.of(context).push(route);
      },
      emptyText: "No Search Results Found",
    );
    return journalList;
  }
}
