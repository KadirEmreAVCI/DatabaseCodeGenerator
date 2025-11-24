#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "TableModel.h"
#include "ColumnListModel.h"

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    TableModel rTournamentTableModel{"Tournament", Position{100, 150}};
    TableModel rMatchTableModel{"Match", Position{450, 150}};
    engine.rootContext()->setContextProperty("tournamentTableModel", &rTournamentTableModel);
    engine.rootContext()->setContextProperty("matchTableModel", &rMatchTableModel);
    
    ColumnListModel rTournamentColumnListModel{{
        new ColumnItemModel("INT",  false, true,  true,   Position(0, 0),   "ID"),
        new ColumnItemModel("TEXT", true,  false, false,  Position(0, 0),   "Season"),
        new ColumnItemModel("TEXT", true,  false, false,  Position(0, 0),   "Category")
    }};
    ColumnListModel rMatchColumnListModel{{
        new ColumnItemModel("INT",  false, true,  false,     Position(0, 0),   "ID"),
        new ColumnItemModel("INT",  false, false, true,     Position(0, 0),   "TournamentID"),
        new ColumnItemModel("REAL", true,  false, false,    Position(0, 0),   "Date"),
        new ColumnItemModel("TEXT", true,  false, false,     Position(0, 0),   "Time")
    }};
    engine.rootContext()->setContextProperty("tournamentColumnListModel", &rTournamentColumnListModel);
    engine.rootContext()->setContextProperty("matchColumnListModel", &rMatchColumnListModel);

    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
