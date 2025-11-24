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
    
    ColumnListModel rTournamentColumnListModel;
    ColumnListModel rMatchColumnListModel;
    engine.rootContext()->setContextProperty("tournamentColumnListModel", &rTournamentColumnListModel);
    engine.rootContext()->setContextProperty("matchColumnListModel", &rMatchColumnListModel);

    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
