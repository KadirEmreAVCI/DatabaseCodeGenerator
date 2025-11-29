#ifndef TABLECONTROLLER_H_
#define TABLECONTROLLER_H_

#include <QObject>
#include <map>

class TableModel;

class TableController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QList<QObject*> tables READ GetTables NOTIFY tablesChanged)
public:
    TableController(QObject *parent = nullptr);
    ~TableController() = default;

    // Getters
    QList<QObject*> GetTables()const;

    void AddTable(TableModel*);
    bool IsNameDuplicated(int iChangedTableID, const QString& sNewName)const;
public slots:
    void onTableNameChangeRequested(int iTableID, const QString& sNewName);
    void onCreateNewTable();
private:
    std::map<int, TableModel*> m_mapTable;
    int m_iNextTableID = 0;
signals:
    void tablesChanged();
    void tableNameChangeRejected(int tableID, const QString &sWarningMessage);
};

#endif // TABLECONTROLLER_H_