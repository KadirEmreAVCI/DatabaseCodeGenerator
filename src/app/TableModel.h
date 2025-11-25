#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include "Model.h"
#include "ColumnListModel.h"

class TableModel : public Model{
    Q_OBJECT
    Q_PROPERTY(ColumnListModel* columnListModel READ GetColumnListModel CONSTANT)
public:
    TableModel(const QString& sName = "", const Position& rPosition = {}, QObject *parent = nullptr);
    virtual ~TableModel()override = default;

    ColumnListModel* GetColumnListModel() const;
    void SetColumnListModel(ColumnListModel* pColumnListModel);
private:
    ColumnListModel* m_pColumnListModel;
};

#endif // TABLEMODEL_H_