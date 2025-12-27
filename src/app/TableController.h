#ifndef TABLECONTROLLER_H_
#define TABLECONTROLLER_H_

#include <QObject>
#include <QRectF>
#include <map>

class TableModel;

class TableController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> tables READ GetTables NOTIFY tablesChanged)
public:
    static TableController& GetInstance();
    TableController(const TableController&) = delete;
    TableController& operator=(const TableController&) = delete;
    ~TableController() = default;

    // Getters
    QList<QObject*> GetTables()const;
    const TableModel* GetTable(int iTableID)const;
    void NewRelationEstablished(int iSourceTableID, int iDestinationTableID);

    void AddTable(TableModel*);
    void TableDeleted(int iTableID);
    bool RelationshipDeleted(int iSourceTableID, int iDestinationTableID);
public slots:
    void onTableNameChangeRequested(int iTableID, const QString& sNewName);
    void onTablePositionChangeRequested(int iTableID, const QPointF& rPointF);
    void onCreateNewTable(const QPointF& rPointF);
    QRectF GetBoundingRect() const;
private:
    TableController(QObject *parent = nullptr);
    bool IsNameDuplicated(int iChangedTableID, const QString& sNewName)const;
    QString NormalizeTableName(const QString& sName) const;
    QString FindRelationColumnName(int iDestinationTableID) const;
    //void DeleteRelationBasedColumnsFromSourceTables(int iDeletedTableID);

    std::map<int, TableModel*> m_mapTable; 
    int m_iNextTableID = 0;
signals:
    void tablesChanged();
    void tableNameChangeRejected(int tableID, const QString &sWarningMessage);
};

#endif // TABLECONTROLLER_H_