#include "ColumnListModel.h"

ColumnListModel::ColumnListModel(QObject *parent)
    : QAbstractListModel(parent)
{    
    AddColumn(new ColumnModel("ID", "INT",  false, true,  true, this));
}
int ColumnListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_vecColumnModels.size();
}
QVariant ColumnListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return {};

    const int row = index.row();
    if (row < 0 || row >= m_vecColumnModels.size())
        return {};

    const ColumnModel* const pColumnModel = m_vecColumnModels.at(row);
    switch (role) {
    case TypeRole:              return pColumnModel->GetType();
    case NameRole:              return pColumnModel->GetName();
    case IsEnabledRole:         return pColumnModel->GetIsEnabled();
    case IsPrimaryKeyRole:      return pColumnModel->GetIsPrimaryKey();
    case IsRelationSourceRole:  return pColumnModel->GetIsRelationSource();
    default:                    return {};
    }
}
QHash<int, QByteArray> ColumnListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[TypeRole] = "type";
    roles[IsEnabledRole] = "isEnabled";
    roles[IsPrimaryKeyRole] = "isPrimaryKey";
    roles[IsRelationSourceRole] = "isRelationSource";
    roles[NameRole] = "name";
    return roles;
}
void ColumnListModel::AddColumn(ColumnModel* pColumnModel)
{
    if (!pColumnModel)
        return;

    pColumnModel->setParent(this);

    const int row = m_vecColumnModels.size();
    beginInsertRows(QModelIndex(), row, row);
    m_vecColumnModels.append(pColumnModel);
    endInsertRows();

    emit countChanged();
}
QVariantMap ColumnListModel::GetColumn(int row) const
{
    QVariantMap map;
    if (row < 0 || row >= m_vecColumnModels.size())
        return map;

    ColumnModel *pColumnModel = m_vecColumnModels.at(row);
    if (!pColumnModel)
        return map;

    map["name"]             = pColumnModel->GetName();          // adapt to your getters
    map["type"]             = pColumnModel->GetType();
    map["isEnabled"]        = pColumnModel->GetIsEnabled();
    map["isPrimaryKey"]     = pColumnModel->GetIsPrimaryKey();
    map["isRelationSource"] = pColumnModel->GetIsRelationSource();
    return map;
}