#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "TableModel.h"

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    TableModel rTournamentTableModel{"Tournament"};
    TableModel rMatchTableModel{"Match"};
    engine.rootContext()->setContextProperty("tournamentTableModel", &rTournamentTableModel);
    engine.rootContext()->setContextProperty("matchTableModel", &rMatchTableModel);

    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
