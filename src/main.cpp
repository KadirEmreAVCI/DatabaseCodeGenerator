#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <iostream>
#include "TableModel.h"
#include "ColumnListModel.h"

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    TableModel rTournamentTableModel{"Tournament", Position{100, 150}};
    if(rTournamentTableModel.GetColumnListModel() != nullptr)
    {
        rTournamentTableModel.GetColumnListModel()->AddColumnItem(new ColumnItemModel("INT",  false, true,  true,  Position(0, 0), "ID"));
        rTournamentTableModel.GetColumnListModel()->AddColumnItem(new ColumnItemModel("TEXT", true,  false, false, Position(0, 0), "Season"));
        rTournamentTableModel.GetColumnListModel()->AddColumnItem(new ColumnItemModel("TEXT", true,  false, false, Position(0, 0), "Category"));
    }
    engine.rootContext()->setContextProperty("tournamentTableModel", &rTournamentTableModel);

    TableModel rMatchTableModel{"Match", Position{450, 150}};
    if(rMatchTableModel.GetColumnListModel() != nullptr)
    {
        rMatchTableModel.GetColumnListModel()->AddColumnItem(new ColumnItemModel("INT",  false, true,  false, Position(0, 0), "ID"));
        rMatchTableModel.GetColumnListModel()->AddColumnItem(new ColumnItemModel("INT",  false, false, true,  Position(0, 0), "TournamentID"));
        rMatchTableModel.GetColumnListModel()->AddColumnItem(new ColumnItemModel("REAL", true,  false, false, Position(0, 0), "Date"));
        rMatchTableModel.GetColumnListModel()->AddColumnItem(new ColumnItemModel("TEXT", true,  false, false, Position(0, 0), "Time"));
    }
    engine.rootContext()->setContextProperty("matchTableModel", &rMatchTableModel);
    
    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
