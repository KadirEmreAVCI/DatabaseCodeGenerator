#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include "Model.h"
#include "ColumnListModel.h"

class TableModel : public Model{
    Q_OBJECT
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)
    Q_PROPERTY(ColumnListModel* columnListModel READ GetColumnListModel CONSTANT)
public:
    TableModel(const QString& sName, const Position& rPosition = {}, QObject *parent = nullptr);
    virtual ~TableModel()override = default;

    // Getters
    QString GetName() const;
    ColumnListModel* GetColumnListModel() const;

    // Setters
    void SetName(const QString &name);
    void SetColumnListModel(ColumnListModel* pColumnListModel);
private:
    QString m_sName;
    ColumnListModel* m_pColumnListModel;
signals:
    void nameChanged();
};

#endif // TABLEMODEL_H_