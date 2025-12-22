#ifndef UICOMMANDBUS_H_
#define UICOMMANDBUS_H_

#include <QObject>
#include <QPointF>
#include <QString>

class UiCommandBus final : public QObject
{
    Q_OBJECT
public:
    explicit UiCommandBus(QObject* parent = nullptr) : QObject(parent) {}

signals:
    // -------------------------------------------------------------------------
    // Controller command signals (emitted by QML; controllers/services listen)
    // -------------------------------------------------------------------------
    void tableDeleteRequested(int tableID);
    void tableNameChangeRequested(int tableID, const QString& newName);
    void tablePositionChangeRequested(int tableID, const QPointF& newPos);
    void newRelationEstablished(int sourceTableID, int destinationTableID);
    // -------------------------------------------------------------------------
};

#endif // UICOMMANDBUS_H_