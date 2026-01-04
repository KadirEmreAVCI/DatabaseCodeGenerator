#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QQuickStyle>
#include <iostream>
#include <memory>

#include "TableModel.h"
#include "ColumnModel.h"
#include "RelationModel.h"
#include "TableController.h"
#include "UiCommandBus.h"

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    // const auto spTournamentTable = std::make_shared<TableModel>(nullptr, "Tournament", QPoint{100, 150});
    // spTournamentTable->AddColumn(std::make_shared<ColumnModel>("Season", "TEXT", true,  false, false));
    // spTournamentTable->AddColumn(std::make_shared<ColumnModel>("Category", "TEXT", true,  false, false));

    // const auto spMatchTable = std::make_shared<TableModel>(nullptr, "Match", QPoint{450, 150});
    // spMatchTable->AddColumn(std::make_shared<ColumnModel>("Date", "REAL", true,  false, false));
    // spMatchTable->AddColumn(std::make_shared<ColumnModel>("Time", "TEXT", true,  false, false));
    
    // TableController::GetInstance().AddTable(spTournamentTable);
    // TableController::GetInstance().AddTable(spMatchTable);
    TableController::GetInstance().AddTable(QPoint{100, 150}, "Tournament");
    TableController::GetInstance().AddTable(QPoint{450, 150}, "Match");
    TableController::GetInstance().onCreateNewRelationRequested(0, 1);

    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::createNewTableRequested,      &TableController::GetInstance(), &TableController::onCreateNewTableRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::changeTableNameRequested,     &TableController::GetInstance(), &TableController::onChangeTableNameRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::tablePositionChangeRequested, &TableController::GetInstance(), &TableController::onTablePositionChangeRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::deleteTableRequested,         &TableController::GetInstance(), &TableController::onDeleteTableRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::createNewRelationRequested,   &TableController::GetInstance(), &TableController::onCreateNewRelationRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::changeRelationshipRequested,  &TableController::GetInstance(), &TableController::onChangeRelationshipRequested);
    QObject::connect(&UiCommandBus::GetInstance(), &UiCommandBus::deleteRelationRequested,      &TableController::GetInstance(), &TableController::onDeleteRelationRequested);

    // Expose to QML
    qmlRegisterUncreatableType<TableModel>("DatabaseCodeGenerator", 1, 0, "TableModel", "Created in C++");
    qmlRegisterUncreatableType<ColumnModel>("DatabaseCodeGenerator", 1, 0, "ColumnModel", "Created in C++");
    
    engine.rootContext()->setContextProperty("tableController", &TableController::GetInstance());
    engine.rootContext()->setContextProperty("uiCommandBus", &UiCommandBus::GetInstance());
    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
