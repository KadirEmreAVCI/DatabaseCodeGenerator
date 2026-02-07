#ifndef UICOMMANDBUS_H_
#define UICOMMANDBUS_H_

#include <QObject>
#include <QPointF>
#include <QString>

class UiCommandBus final : public QObject
{
    Q_OBJECT
public:
    UiCommandBus(QObject* parent = nullptr);
    UiCommandBus(const UiCommandBus&) = delete;
    UiCommandBus& operator=(const UiCommandBus&) = delete;
    ~UiCommandBus() = default;
signals:
    // Table related commands
    void createNewTableRequested(const QPointF& pos);
    void deleteTableRequested(int tableID);
    void changeTableNameRequested(int tableID, const QString& newName);
    void tablePositionChangeRequested(int tableID, const QPointF& newPos);
    
    // Relation related commands
    void createNewRelationRequested(int sourceTableID, int destinationTableID);
    void deleteRelationRequested(int ID);
    void changeRelationshipRequested(int ID, const QString& relationship);

    // Column related commands
    void createNewColumnRequested(int tableID, const QString& name, const QString& type, bool notNull, bool isPrimaryKey, bool autoIncrement, bool unique);
    void deleteColumnRequested(int tableID, int columnID);
    void reorderColumnRequested(int tableID, int fromColumnID, int toColumnID);
};

#endif // UICOMMANDBUS_H_