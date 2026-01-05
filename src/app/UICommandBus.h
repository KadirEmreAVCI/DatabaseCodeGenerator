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
    signals:
    void createNewColumnRequested(int tableID, const QString& name, const QString& type, bool notNull, bool isPrimaryKey, bool autoIncrement, bool unique);

};

#endif // UICOMMANDBUS_H_