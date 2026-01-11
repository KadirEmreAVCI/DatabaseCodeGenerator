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

    void AddTable(const QPointF& rPointF, const QString& sTableName);
public slots:
    void onDeleteRelationRequested(int iID);
    void onChangeRelationshipRequested(int iID, const QString& sRelationship);
    void onCreateNewRelationRequested(int iSourceTableID, int iDestinationTableID);
    
    void onDeleteTableRequested(int iTableID);
    void onChangeTableNameRequested(int iTableID, const QString& sNewName);
    void onTablePositionChangeRequested(int iTableID, const QPointF& rPointF);
    void onCreateNewTableRequested(const QPointF& rPointF);

    void onCreateNewColumnRequested(int iTableID, const QString& sName, const QString& sType, bool blNotNull, bool blIsPrimaryKey, bool blAutoIncrement, bool blUnique);
    QRectF GetBoundingRect() const;
private:
    TableController(QObject *parent = nullptr);
    TableModel* GetTable(int iTableID);
    RelationModel* GetRelation(int iRelationID);
    void AddRelation(int iSourceTableID, int iDestinationTableID);
    bool IsNameDuplicated(int iChangedTableID, const QString& sNewName)const;
    QString NormalizeTableName(const QString& sName) const;
    bool IsRelationExists(int iSourceTableID, int iDestinationTableID)const;
    std::vector<int> GetRelationIDsIfTableInvolved(int iTableID);

    std::vector<std::unique_ptr<TableModel>> m_vecupTables;
    std::vector<std::unique_ptr<RelationModel>> m_vecupRelations;
    int m_iNextTableID = 0;
    int ms_iNextRelationID = 0;
signals:
    void tablesChanged();
    void relationsChanged();
    void tableNameChangeRejected(int tableID, const QString &sWarningMessage);
};

#endif // TABLECONTROLLER_H_