#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <iostream>

#include "TableModel.h"
#include "ColumnListModel.h"
#include "RelationModel.h"
#include "TableController.h"
#include "RelationController.h"
#include "UiCommandBus.h"

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    auto pTournamentTableModel = new TableModel(nullptr, "Tournament", QPoint{100, 150});
    if (pTournamentTableModel->GetColumnListModel() != nullptr)
    {
        pTournamentTableModel->GetColumnListModel()->AddColumn(new ColumnModel("Season", "TEXT", true,  false, false));
        pTournamentTableModel->GetColumnListModel()->AddColumn(new ColumnModel("Category", "TEXT", true,  false, false));
    }

    auto pMatchTableModel = new TableModel(nullptr, "Match", QPoint{450, 150});
    if (pMatchTableModel->GetColumnListModel() != nullptr)
    {
        pMatchTableModel->GetColumnListModel()->AddColumn(new ColumnModel("TournamentID", "INT",  false, false, true));
        pMatchTableModel->GetColumnListModel()->AddColumn(new ColumnModel("Date", "REAL", true,  false, false));
        pMatchTableModel->GetColumnListModel()->AddColumn(new ColumnModel("Time", "TEXT", true,  false, false));
    }

    auto pTableController = new TableController;
    pTableController->AddTable(pTournamentTableModel);
    pTableController->AddTable(pMatchTableModel);

    auto pRelationController = new RelationController;
    pRelationController->AddRelation(new RelationModel(pTournamentTableModel, pMatchTableModel, "1..*"));

    // Keep your existing controller-to-controller connection
    QObject::connect(pTableController, &TableController::tableDeleted,
                     pRelationController, &RelationController::OnTableDeleted);

    auto pUiCommandBus = new UiCommandBus;

    QObject::connect(pUiCommandBus, &UiCommandBus::tableDeleteRequested,
                     pTableController, &TableController::onTableDeleteRequested);

    QObject::connect(pUiCommandBus, &UiCommandBus::tableNameChangeRequested,
                     pTableController, &TableController::onTableNameChangeRequested);

    QObject::connect(pUiCommandBus, &UiCommandBus::tablePositionChangeRequested,
                     pTableController, &TableController::onTablePositionChangeRequested);

    // Expose to QML
    engine.rootContext()->setContextProperty("tableController", pTableController);
    engine.rootContext()->setContextProperty("relationController", pRelationController);
    engine.rootContext()->setContextProperty("uiCommandBus", pUiCommandBus);
    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
