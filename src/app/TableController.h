#ifndef TABLECONTROLLER_H_
#define TABLECONTROLLER_H_

#include <QObject>
#include <QRectF>
#include <map>
#include <memory>

class TableModel;
class RelationModel;

class TableController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> tables READ GetTableList NOTIFY tablesChanged)
    Q_PROPERTY(QList<QObject*> relations READ GetRelationList NOTIFY relationsChanged)
public:
    static TableController& GetInstance();
    TableController(const TableController&) = delete;
    TableController& operator=(const TableController&) = delete;
    ~TableController() = default;

    // Getters
    QList<QObject*> GetTableList()const;
    QList<QObject*> GetRelationList()const;

    void AddTable(std::shared_ptr<TableModel> spTable);
    void AddRelation(int iSourceTableID, int iDestinationTableID);
public slots:
    void onTableDeleteRequested(int iTableID);
    void onRelationshipDeleteRequested(int iID);
    void onRelationshipChangeRequested(int iID, const QString& sRelationship);
    void onNewRelationEstablished(int iSourceTableID, int iDestinationTableID);
    void onTableNameChangeRequested(int iTableID, const QString& sNewName);
    void onTablePositionChangeRequested(int iTableID, const QPointF& rPointF);
    void onCreateNewTable(const QPointF& rPointF);
    QRectF GetBoundingRect() const;
private:
    TableController(QObject *parent = nullptr);
    std::shared_ptr<TableModel> GetTable(int iTableID)const;
    std::shared_ptr<RelationModel> GetRelation(int iRelationID)const;
    std::map<int, std::shared_ptr<RelationModel>> GatherRelationsFromTables()const;
    bool IsNameDuplicated(int iChangedTableID, const QString& sNewName)const;
    QString NormalizeTableName(const QString& sName) const;
    bool IsRelationExists(int iSourceTableID, int iDestinationTableID)const;
    void RelationsChanged();

    std::map<int, std::shared_ptr<TableModel>> m_mapspTable;
    std::map<int, std::shared_ptr<RelationModel>> m_mapspRelations;
    int m_iNextTableID = 0;
signals:
    void tablesChanged();
    void relationsChanged();
    void tableNameChangeRejected(int tableID, const QString &sWarningMessage);
};

#endif // TABLECONTROLLER_H_