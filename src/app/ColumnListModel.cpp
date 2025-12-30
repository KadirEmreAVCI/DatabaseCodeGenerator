#include "ColumnListModel.h"
#include "ColumnModel.h"

ColumnListModel::ColumnListModel(QObject *parent)
    : QAbstractListModel(parent)
{    
    AddColumn(std::make_shared<ColumnModel>("ID", "INT",  false, true,  true));
}
int ColumnListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_vecspColumns.size();
}
QVariant ColumnListModel::data(const QModelIndex &index, int role) const
{
    if (index.isValid())
    {
        const int iRow = index.row();
        if (IsRowIndexValid(iRow))
        {
            const std::shared_ptr<const ColumnModel> spColumnModel = m_vecspColumns.at(iRow);
            switch (role) {
            case TypeRole:              return spColumnModel->GetType();
            case NameRole:              return spColumnModel->GetName();
            case IsEnabledRole:         return spColumnModel->GetIsEnabled();
            case IsPrimaryKeyRole:      return spColumnModel->GetIsPrimaryKey();
            case IsRelationSourceRole:  return spColumnModel->GetIsRelationSource();
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
void ColumnListModel::AddColumn(std::shared_ptr<ColumnModel> spColumn)
{
    if (spColumn != nullptr)
    {
        spColumn->setParent(this);
        int iInsertionRow = m_vecspColumns.size();
        if(!spColumn->GetIsEnabled())
        {
            const auto iterColumn = std::find_if_not(m_vecspColumns.begin(), m_vecspColumns.end(),
                [](const std::shared_ptr<ColumnModel> spColumn){
                    return !spColumn->GetIsEnabled();
                });
            if (iterColumn != m_vecspColumns.end())
            {
                iInsertionRow = std::distance(m_vecspColumns.begin(), iterColumn);
            }
        }

        beginInsertRows(QModelIndex(), iInsertionRow, iInsertionRow);
        m_vecspColumns.insert(m_vecspColumns.begin() + iInsertionRow, spColumn);
        endInsertRows();

        emit countChanged();
    }
    else
    {
        qWarning("Attempted to add a null ColumnModel.");
    }
}
bool ColumnListModel::RemoveColumn(int iRow)
{
    if(IsRowIndexValid(iRow)) 
    {
        beginRemoveRows(QModelIndex(), iRow, iRow);
        std::shared_ptr<ColumnModel> spColumn = m_vecspColumns[iRow];
        m_vecspColumns.erase(m_vecspColumns.begin() + iRow);
        endRemoveRows();
        if(spColumn != nullptr)
        {
            spColumn->deleteLater();
        }
        emit countChanged();
        return true;
    }
    else
    {
        qWarning("Attempted to remove a ColumnModel with an invalid row index.");
        return false;
    }
}
bool ColumnListModel::RemoveRelationBasedColumn(int iRelationID)
{
    for(int i = 0; i < static_cast<int>(m_vecspColumns.size()); ++i)
    {
        if(m_vecspColumns[i]->GetIsRelationSource() && m_vecspColumns[i]->GetRelationID() == iRelationID)
        {
            return RemoveColumn(i);
        }
    }
    qWarning("Attempted to remove a ColumnModel with a name that does not exist.");
    return false;
}
int ColumnListModel::GetRelationBasedColumnIdx(int iRelationID)const
{
    for(int i = 0; i < static_cast<int>(m_vecspColumns.size()); ++i)
    {
        if(m_vecspColumns[i]->GetRelationID() == iRelationID)
        {
            return i;
        }
    }
    return -1; // Not found
}
void ColumnListModel::RenameRelationBasedColumn(int iRelationID, const QString& sNewRelationBasedColumnName)
{
    for(int i = 0; i < static_cast<int>(m_vecspColumns.size()); ++i)
    {
        if(m_vecspColumns[i]->GetIsRelationSource() && m_vecspColumns[i]->GetRelationID() == iRelationID)
        {
            m_vecspColumns[i]->SetName(sNewRelationBasedColumnName);
        }
    }
}
bool ColumnListModel::IsRowIndexValid(int iRow) const
{
    return !(iRow < 0 || iRow >= static_cast<int>(m_vecspColumns.size()));
}
QVariantMap ColumnListModel::GetColumn(int iRow) const
{
    QVariantMap map;
    if(IsRowIndexValid(iRow))
    {
        const std::shared_ptr<const ColumnModel> spColumn = m_vecspColumns.at(iRow);
        if (spColumn != nullptr)
        {
            map["name"]             = spColumn->GetName();          // adapt to your getters
            map["type"]             = spColumn->GetType();
            map["isEnabled"]        = spColumn->GetIsEnabled();
            map["isPrimaryKey"]     = spColumn->GetIsPrimaryKey();
            map["isRelationSource"] = spColumn->GetIsRelationSource();
        }
    }
    return map;
}