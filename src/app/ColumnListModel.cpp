#include "ColumnListModel.h"

ColumnListModel::ColumnListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    // Example data initialization
    m_vecColumnItems.append(new ColumnItemModel("INT",  Position(0, 0), "ID", this));
    m_vecColumnItems.append(new ColumnItemModel("TEXT", Position(0, 0), "SEASON", this));
    m_vecColumnItems.append(new ColumnItemModel("TEXT", Position(0, 0), "CATEGORY", this));
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
    case TypeRole:  return pColumnItem->GetType();
    case NameRole:  return pColumnItem->GetName();
    case XRole:     return pColumnItem->GetX();
    case YRole:     return pColumnItem->GetY();
    default:        return {};
    }
}
QHash<int, QByteArray> ColumnListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[TypeRole] = "type";
    roles[NameRole] = "name";
    roles[XRole]    = "x";
    roles[YRole]    = "y";
    return roles;
}