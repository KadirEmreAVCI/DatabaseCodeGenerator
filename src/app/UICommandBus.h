#ifndef UICOMMANDBUS_H_
#define UICOMMANDBUS_H_

#include <QObject>
#include <QPointF>
#include <QString>

class UiCommandBus final : public QObject
{
    Q_OBJECT
public:
    static UiCommandBus& GetInstance();
    UiCommandBus(const UiCommandBus&) = delete;
    UiCommandBus& operator=(const UiCommandBus&) = delete;
    ~UiCommandBus() = default;
private:
    explicit UiCommandBus(QObject* parent = nullptr);
signals:
    // -------------------------------------------------------------------------
    // Controller command signals (emitted by QML; controllers/services listen)
    // -------------------------------------------------------------------------
    void tableDeleteRequested(int tableID);
    void tableNameChangeRequested(int tableID, const QString& newName);
    void tablePositionChangeRequested(int tableID, const QPointF& newPos);
    void newRelationEstablished(int sourceTableID, int destinationTableID);
    void relationshipChangeRequested(int sourceTableID, int destinationTableID, const QString& relationship);
    void relationshipDeleteRequested(int sourceTableID, int destinationTableID);
    // -------------------------------------------------------------------------
};

#endif // UICOMMANDBUS_H_