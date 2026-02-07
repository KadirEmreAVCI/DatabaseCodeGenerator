#include "AppController.h"
#include "TableController.h"
#include "UICommandBus.h"
#include "TableModel.h"
#include "ColumnModel.h"
#include "RelationModel.h"
#include <QQmlContext>

AppController& AppController::GetInstance()
{
    static AppController instance;
    return instance;
}
AppController::AppController(QObject *parent) : 
    QObject{parent}, 
    m_upTableController{std::make_unique<TableController>()},
    m_upUiCommandBus{std::make_unique<UiCommandBus>()}
{
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::createNewTableRequested,      m_upTableController.get(), &TableController::onCreateNewTableRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::changeTableNameRequested,     m_upTableController.get(), &TableController::onChangeTableNameRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::tablePositionChangeRequested, m_upTableController.get(), &TableController::onTablePositionChangeRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::deleteTableRequested,         m_upTableController.get(), &TableController::onDeleteTableRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::createNewRelationRequested,   m_upTableController.get(), &TableController::onCreateNewRelationRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::changeRelationshipRequested,  m_upTableController.get(), &TableController::onChangeRelationshipRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::deleteRelationRequested,      m_upTableController.get(), &TableController::onDeleteRelationRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::createNewColumnRequested,     m_upTableController.get(), &TableController::onCreateNewColumnRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::deleteColumnRequested,        m_upTableController.get(), &TableController::onDeleteColumnRequested);
    QObject::connect(m_upUiCommandBus.get(), &UiCommandBus::reorderColumnRequested,       m_upTableController.get(), &TableController::onReorderColumnRequested);
}
void AppController::Start(QQmlApplicationEngine& rEngine)
{
    m_upTableController->AddTable(QPoint{100, 150}, "Tournament");
    m_upTableController->AddTable(QPoint{450, 150}, "Match");
    m_upTableController->onCreateNewRelationRequested(0, 1);

    // Expose to QML
    qmlRegisterUncreatableType<TableModel>("DatabaseCodeGenerator", 1, 0, "TableModel", "Created in C++");
    qmlRegisterUncreatableType<ColumnModel>("DatabaseCodeGenerator", 1, 0, "ColumnModel", "Created in C++");
    
    rEngine.rootContext()->setContextProperty("tableController", m_upTableController.get());
    rEngine.rootContext()->setContextProperty("uiCommandBus", m_upUiCommandBus.get());
    rEngine.loadFromModule("DatabaseCodeGenerator", "Main");
}