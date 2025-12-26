#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QQuickStyle>
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

    TableController::GetInstance().AddTable(pTournamentTableModel);
    TableController::GetInstance().AddTable(pMatchTableModel);

    RelationController::GetInstance().AddRelation(new RelationModel(pTournamentTableModel, pMatchTableModel, "1..*"));

    QObject::connect(&TableController::GetInstance(), &TableController::tableDeleted, &RelationController::GetInstance(), &RelationController::OnTableDeleted);

    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::tableDeleteRequested,         &TableController::GetInstance(), &TableController::onTableDeleteRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::tableNameChangeRequested,     &TableController::GetInstance(), &TableController::onTableNameChangeRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::tablePositionChangeRequested, &TableController::GetInstance(), &TableController::onTablePositionChangeRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::relationshipDeleteRequested,  &TableController::GetInstance(), &TableController::onRelationshipDeleteRequested);

    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::newRelationEstablished,       &RelationController::GetInstance(), &RelationController::onNewRelationEstablished);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::relationshipChangeRequested,  &RelationController::GetInstance(), &RelationController::onRelationshipChangeRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::relationshipDeleteRequested,  &RelationController::GetInstance(), &RelationController::onRelationshipDeleteRequested);

    // Expose to QML
    engine.rootContext()->setContextProperty("tableController", &TableController::GetInstance());
    engine.rootContext()->setContextProperty("relationController", &RelationController::GetInstance());
    engine.rootContext()->setContextProperty("uiCommandBus", &UiCommandBus::GetInstance());
    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
