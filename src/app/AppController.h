#ifndef APPCONTROLLER_H_
#define APPCONTROLLER_H_
#include <QQmlApplicationEngine>
#include <QObject>
#include <memory>

class TableController;
class UiCommandBus;
class AppController : public QObject {
    Q_OBJECT
public:
    static AppController& GetInstance();
    AppController(const AppController&) = delete;
    AppController& operator=(const AppController&) = delete;
    ~AppController() = default;
    void Start(QQmlApplicationEngine& rEngine);
private:
    AppController(QObject *parent = nullptr);
    std::unique_ptr<TableController> m_upTableController;
    std::unique_ptr<UiCommandBus> m_upUiCommandBus; 
};

#endif // APPCONTROLLER_H_