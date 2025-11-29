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

    auto pTournamentTableModel = new TableModel("Tournament", Position{100, 150});
    if(pTournamentTableModel->GetColumnListModel() != nullptr)
    {
        pTournamentTableModel->GetColumnListModel()->AddColumn(new ColumnModel("ID", "INT",  false, true,  true));
        pTournamentTableModel->GetColumnListModel()->AddColumn(new ColumnModel("Season", "TEXT", true,  false, false));
        pTournamentTableModel->GetColumnListModel()->AddColumn(new ColumnModel("Category", "TEXT", true,  false, false));
    }

    auto pMatchTableModel = new TableModel("Match", Position{450, 150});
    if(pMatchTableModel->GetColumnListModel() != nullptr)
    {
        pMatchTableModel->GetColumnListModel()->AddColumn(new ColumnModel("ID", "INT",  false, true,  false));
        pMatchTableModel->GetColumnListModel()->AddColumn(new ColumnModel("TournamentID", "INT",  false, false, true));
        pMatchTableModel->GetColumnListModel()->AddColumn(new ColumnModel("Date", "REAL", true,  false, false));
        pMatchTableModel->GetColumnListModel()->AddColumn(new ColumnModel("Time", "TEXT", true,  false, false));
    }

    auto pTableController = new TableController;
    pTableController->AddTable(pTournamentTableModel);
    pTableController->AddTable(pMatchTableModel);
    
    engine.rootContext()->setContextProperty("tableController", pTableController);
    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
