#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QQuickStyle>
#include <iostream>
#include <memory>

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

    auto spTournamentTable = std::make_shared<TableModel>(nullptr, "Tournament", QPoint{100, 150});
    if (spTournamentTable->GetColumnListModel() != nullptr)
    {
        spTournamentTable->GetColumnListModel()->AddColumn(std::make_shared<ColumnModel>("Season", "TEXT", true,  false, false));
        spTournamentTable->GetColumnListModel()->AddColumn(std::make_shared<ColumnModel>("Category", "TEXT", true,  false, false));
    }

    auto spMatchTable = std::make_shared<TableModel>(nullptr, "Match", QPoint{450, 150});
    if (spMatchTable->GetColumnListModel() != nullptr)
    {
        spMatchTable->GetColumnListModel()->AddColumn(std::make_shared<ColumnModel>("TournamentID", "INT",  false, false, true));
        spMatchTable->GetColumnListModel()->AddColumn(std::make_shared<ColumnModel>("Date", "REAL", true,  false, false));
        spMatchTable->GetColumnListModel()->AddColumn(std::make_shared<ColumnModel>("Time", "TEXT", true,  false, false));
    }

    TableController::GetInstance().AddTable(spTournamentTable);
    TableController::GetInstance().AddTable(spMatchTable);
    RelationController::GetInstance().AddRelation(std::make_shared<RelationModel>(spTournamentTable, spMatchTable, "1..*"));

    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::tableNameChangeRequested,     &TableController::GetInstance(), &TableController::onTableNameChangeRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::tablePositionChangeRequested, &TableController::GetInstance(), &TableController::onTablePositionChangeRequested);

    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::tableDeleteRequested,         &RelationController::GetInstance(), &RelationController::onTableDeleteRequested);
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
