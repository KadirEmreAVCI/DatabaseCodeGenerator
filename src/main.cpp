#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "AppController.h"

int main(int argc, char **argv)
{
    QGuiApplication rApplication(argc, argv);
    QQmlApplicationEngine rEngine;
    AppController::GetInstance().Start(rEngine);
    if (rEngine.rootObjects().isEmpty())
    {
        return -1;
    }
    return rApplication.exec();
}
