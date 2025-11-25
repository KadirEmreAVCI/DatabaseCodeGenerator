#include "ColumnListModel.h"

ColumnListModel::ColumnListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    // Example data initialization
    
}
ColumnListModel::ColumnListModel(const QVector<ColumnItemModel*>& vecColumnItems, QObject *parent)
    : QAbstractListModel(parent), m_vecColumnItems(vecColumnItems)
{
}
int ColumnListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_vecColumnItems.size();
}
QVariant ColumnListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return {};

    const int row = index.row();
    if (row < 0 || row >= m_vecColumnItems.size())
        return {};

    const ColumnItemModel* const pColumnItem = m_vecColumnItems.at(row);
    switch (role) {
    case TypeRole:              return pColumnItem->GetType();
    case NameRole:              return pColumnItem->GetName();
    case IsEnabledRole:         return pColumnItem->GetIsEnabled();
    case IsPrimaryKeyRole:      return pColumnItem->GetIsPrimaryKey();
    case IsRelationSourceRole:  return pColumnItem->GetIsRelationSource();
    case XRole:                 return pColumnItem->GetX();
    case YRole:                 return pColumnItem->GetY();
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
    roles[XRole] = "x";
    roles[YRole] = "y";
    return roles;
}
void ColumnListModel::AddColumnItem(ColumnItemModel* pColumnItem)
{
    if (!pColumnItem)
        return;

    pColumnItem->setParent(this);

    const int row = m_vecColumnItems.size();
    beginInsertRows(QModelIndex(), row, row);
    m_vecColumnItems.append(pColumnItem);
    endInsertRows();

    emit countChanged();
}
QVariantMap ColumnListModel::get(int row) const
{
    QVariantMap map;
    if (row < 0 || row >= m_vecColumnItems.size())
        return map;

    ColumnItemModel *item = m_vecColumnItems.at(row);
    if (!item)
        return map;

    map["name"]             = item->GetName();          // adapt to your getters
    map["type"]             = item->GetType();
    map["isEnabled"]        = item->GetIsEnabled();
    map["isPrimaryKey"]     = item->GetIsPrimaryKey();
    map["isRelationSource"] = item->GetIsRelationSource();
    return map;
}