#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QDir>
#include <QDebug>

int main(int argc, char **argv)
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    engine.loadFromModule("DatabaseCodeGenerator", "Main");

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
