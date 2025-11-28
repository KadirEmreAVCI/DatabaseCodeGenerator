#ifndef TABLECONTROLLER_H_
#define TABLECONTROLLER_H_

#include <QObject>
#include <map>

class TableModel;

class TableController : public QObject {
    Q_OBJECT
public:
    TableController(QObject *parent = nullptr);
    ~TableController() = default;

    void AddTable(TableModel*);
public slots:
    void onTableNameChangeRequested(int iTableID, const QString& sNewName);
private:
    std::map<int, TableModel*> m_mapTable;
};

#endif // TABLECONTROLLER_H_