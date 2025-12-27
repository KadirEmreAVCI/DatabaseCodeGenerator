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
    if (index.isValid())
    {
        const int iRow = index.row();
        if (IsRowIndexValid(iRow))
        {
            const ColumnModel* const pColumnModel = m_vecColumnModels.at(iRow);
            switch (role) {
            case TypeRole:              return pColumnModel->GetType();
            case NameRole:              return pColumnModel->GetName();
            case IsEnabledRole:         return pColumnModel->GetIsEnabled();
            case IsPrimaryKeyRole:      return pColumnModel->GetIsPrimaryKey();
            case IsRelationSourceRole:  return pColumnModel->GetIsRelationSource();
            default:                    return {};
            }
        }
    }
    return {};
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
    if (pColumnModel != nullptr)
    {
        pColumnModel->setParent(this);
        
        int iInsertionRow = m_vecColumnModels.size();
        if(!pColumnModel->GetIsEnabled())
        {
            const auto iterColumn = std::find_if_not(m_vecColumnModels.begin(), m_vecColumnModels.end(),
                [](const ColumnModel* const pColumn){
                    return !pColumn->GetIsEnabled();
                });
            if (iterColumn != m_vecColumnModels.end())
            {
                iInsertionRow = std::distance(m_vecColumnModels.begin(), iterColumn);
            }
        }

        beginInsertRows(QModelIndex(), iInsertionRow, iInsertionRow);
        m_vecColumnModels.insert(m_vecColumnModels.begin() + iInsertionRow, pColumnModel);
        endInsertRows();

        emit countChanged();
    }
    else
    {
        qWarning("Attempted to add a null ColumnModel.");
    }
}
void ColumnListModel::RemoveColumn(int iRow)
{
    if(IsRowIndexValid(iRow)) 
    {
        beginRemoveRows(QModelIndex(), iRow, iRow);
        ColumnModel* const pColumn = m_vecColumnModels[iRow];
        m_vecColumnModels.erase(m_vecColumnModels.begin() + iRow);
        endRemoveRows();
        if(pColumn != nullptr)
        {
            pColumn->deleteLater();
        }
        emit countChanged();
    }
    else
    {
        qWarning("Attempted to remove a ColumnModel with an invalid row index.");
    }
}
bool ColumnListModel::IsRowIndexValid(int iRow) const
{
    return !(iRow < 0 || iRow >= static_cast<int>(m_vecColumnModels.size()));
}
QVariantMap ColumnListModel::GetColumn(int iRow) const
{
    QVariantMap map;
    if(IsRowIndexValid(iRow))
    {
        const ColumnModel* const pColumnModel = m_vecColumnModels.at(iRow);
        if (pColumnModel != nullptr)
        {
            map["name"]             = pColumnModel->GetName();          // adapt to your getters
            map["type"]             = pColumnModel->GetType();
            map["isEnabled"]        = pColumnModel->GetIsEnabled();
            map["isPrimaryKey"]     = pColumnModel->GetIsPrimaryKey();
            map["isRelationSource"] = pColumnModel->GetIsRelationSource();
        }
    }
    return map;
}