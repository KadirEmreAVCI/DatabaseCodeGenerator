#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <iostream>
#include "TableModel.h"
#include "ColumnListModel.h"
#include "TableController.h"

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    TableModel rTournamentTableModel{0, "Tournament", Position{100, 150}};
    if(rTournamentTableModel.GetColumnListModel() != nullptr)
    {
        rTournamentTableModel.GetColumnListModel()->AddColumnItem(new ColumnModel("ID", "INT",  false, true,  true));
        rTournamentTableModel.GetColumnListModel()->AddColumnItem(new ColumnModel("Season", "TEXT", true,  false, false));
        rTournamentTableModel.GetColumnListModel()->AddColumnItem(new ColumnModel("Category", "TEXT", true,  false, false));
    }
    engine.rootContext()->setContextProperty("tournamentTableModel", &rTournamentTableModel);

    TableModel rMatchTableModel{1, "Match", Position{450, 150}};
    if(rMatchTableModel.GetColumnListModel() != nullptr)
    {
        rMatchTableModel.GetColumnListModel()->AddColumnItem(new ColumnModel("ID", "INT",  false, true,  false));
        rMatchTableModel.GetColumnListModel()->AddColumnItem(new ColumnModel("TournamentID", "INT",  false, false, true));
        rMatchTableModel.GetColumnListModel()->AddColumnItem(new ColumnModel("Date", "REAL", true,  false, false));
        rMatchTableModel.GetColumnListModel()->AddColumnItem(new ColumnModel("Time", "TEXT", true,  false, false));
    }
    engine.rootContext()->setContextProperty("matchTableModel", &rMatchTableModel);

    TableController rTableController;
    rTableController.AddTable(&rTournamentTableModel);
    rTableController.AddTable(&rMatchTableModel);
    engine.rootContext()->setContextProperty("tableController", &rTableController);

    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
