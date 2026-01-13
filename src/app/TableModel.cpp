#include "TableModel.h"
#include "ColumnModel.h"
#include "RelationModel.h"
#include <QDebug>
#include <QTimer>

TableModel::TableModel(int iID, const QString& sName, const QPointF& rPointF, qreal rWidth, qreal rHeight, QObject *parent) 
    : Model(iID, parent), m_sName{sName}, m_rPointF{rPointF}, m_rWidth{rWidth}, m_rHeight{rHeight}
{
    const QString sColumnName = "ID";
    const QString sColumnType = "INT"; 
    const bool blNotNull = true;
    const bool blIsPrimaryKey = true;
    const bool blAutoIncrement = true;
    const bool blUnique = true;
    const bool blIsRelationSource = false;
    AddColumn(std::make_unique<ColumnModel>(m_uiNextColumnID++, sColumnName, sColumnType, blNotNull, blIsPrimaryKey, blAutoIncrement, blUnique, blIsRelationSource));
}
void TableModel::AddColumn(std::unique_ptr<ColumnModel> upColumn)
{
    if (upColumn !=  nullptr)
    {
        upColumn->setParent(this);
        int insertionIndex = static_cast<int>(m_vecupColumns.size());
        if (!upColumn->GetIsEnabled())
        {
            // Find first enabled column (same behavior as your QAbstractListModel version)
            const auto it = std::find_if(m_vecupColumns.begin(), m_vecupColumns.end(), [](const std::unique_ptr<ColumnModel>& pCol){
                    return pCol && pCol->GetIsEnabled();
                });

            insertionIndex = static_cast<int>(std::distance(m_vecupColumns.begin(), it));
        }
        m_vecupColumns.insert(m_vecupColumns.begin() + insertionIndex, std::move(upColumn));
        emit columnsChanged();
    }
    else
    {
        qWarning("Attempted to add a null ColumnModel.");
    }
}
bool TableModel::RemoveColumn(int iRow)
{
    if (IsRowIndexValid(iRow))
    {
        ColumnModel* pColumn = m_vecupColumns[iRow].release();
        m_vecupColumns.erase(m_vecupColumns.begin() + iRow);
        if (pColumn)
        {
            QTimer::singleShot(0, pColumn, &QObject::deleteLater);  // In order to delay deletion by 2 ticks, otherwise program crashes.
        }
        emit columnsChanged();
        return true;
    }
    else
    {
        qWarning("Attempted to remove a ColumnModel with an invalid row index.");
        return false;
    }
}
bool TableModel::RenameColumn(int iRow, const QString& sNewName)
{
    if (IsRowIndexValid(iRow))
    {
        ColumnModel* pColumn = m_vecupColumns[iRow].get();
        if (pColumn != nullptr)
        {
            pColumn->SetName(sNewName);
            return true;    
        }
        else
        {
            qWarning("ColumnModel at given row is null.");
            return false;
        }
    }
    else
    {   
        qWarning("Attempted to rename a ColumnModel with an invalid row index.");
        return false;
    }
}
QString TableModel::GetName() const
{
    return m_sName;
}
QPointF TableModel::GetPointF()const
{
    return m_rPointF;
}
qreal TableModel::GetWidth()const
{
    return m_rWidth;
}
qreal TableModel::GetHeight()const
{
    return m_rHeight;
}
QList<QObject*> TableModel::GetColumnList() const
{
    QList<QObject*> lsColumn;
    lsColumn.reserve(static_cast<int>(m_vecupColumns.size()));
    for (const auto& upColumn : m_vecupColumns) 
    {
        if (upColumn != nullptr) 
        {
            lsColumn.append(upColumn.get());
        } 
    }
    return lsColumn;
}
void TableModel::SetName(const QString &sName)
{
    if(m_sName != sName)
    {
        m_sName = sName;
        emit nameChanged();
        for(auto pIncomingRelation : m_vecIncomingRelations)
        {
            if(pIncomingRelation != nullptr)
            {
                pIncomingRelation->DestinationTableRenamed();
            }
        }
    }
}
void TableModel::SetPoint(const QPointF& rPointF)
{
    if(m_rPointF != rPointF)
    {
        m_rPointF = rPointF;
        emit pointChanged();
    }
}
void TableModel::SetWidth(qreal rWidth)
{
    m_rWidth = rWidth;
}
void TableModel::SetHeight(qreal rHeight)
{
    m_rHeight = rHeight;
}
bool TableModel::IsRowIndexValid(int iRow) const
{
    return !(iRow < 0 || iRow >= static_cast<int>(m_vecupColumns.size()));
}
void TableModel::Attach(const RelationModel* pRelation, RelationRole eRelationRole)
{
    if(pRelation != nullptr)
    {
        if(eRelationRole == RelationRole::eOutgoing)
        {
            AddRelationBasedColumn(pRelation->GetID(), pRelation->GetRelationBasedColumnName());
            m_vecOutgoingRelations.push_back(pRelation);
        }
        else if(eRelationRole == RelationRole::eIncoming)
        {
            m_vecIncomingRelations.push_back(pRelation);
        }
    }
}   
void TableModel::Detach(const RelationModel* pRelation, RelationRole eRelationRole)
{
    if(pRelation != nullptr)
    {
        if(eRelationRole == RelationRole::eOutgoing)
        {
            if(RemoveRelationBasedColumn(pRelation->GetID()))
            {
                std::erase(m_vecOutgoingRelations, pRelation);
            }
            else
            {
                qDebug() << "TableModel::Detach Relation based column could not be removed, relation ID: " << pRelation->GetID();
            }
        }
        else if(eRelationRole == RelationRole::eIncoming)
        {
            std::erase(m_vecIncomingRelations, pRelation);
        }
    }
}
int TableModel::GetColumnRowIdxByRelationID(int iRelationID) const
{
    for (int iRowIdx = 0; iRowIdx < static_cast<int>(m_vecupColumns.size()); ++iRowIdx)
    {
        const ColumnModel* pColumn = m_vecupColumns[iRowIdx].get();
        if (pColumn && pColumn->GetIsRelationSource() && pColumn->GetRelationID() == iRelationID)
        {
            return iRowIdx;
        }
    }
    return -1; // Not found
}
void TableModel::AddRelationBasedColumn(int iRelationID, const QString& sRelationBasedColumnName)
{
    const QString sRelationColumnType = "INT"; 
    const bool blNotNull = true;
    const bool blIsPrimaryKey = false;
    const bool blAutoIncrement = false;
    const bool blUnique = false;
    const bool blIsRelationSource = true;
    AddColumn(std::make_unique<ColumnModel>(m_uiNextColumnID++,
                                            sRelationBasedColumnName, 
                                            sRelationColumnType, 
                                            blNotNull, 
                                            blIsPrimaryKey, 
                                            blAutoIncrement, 
                                            blUnique, 
                                            blIsRelationSource, 
                                            iRelationID));
}
bool TableModel::RemoveRelationBasedColumn(int iRelationID)
{
    if(RemoveColumn(GetColumnRowIdxByRelationID(iRelationID)))
    {
        return true;
    }
    else
    {
        qWarning("Attempted to remove a ColumnModel with a name that does not exist.");
        return false;
    }
}
int TableModel::GetColumnRowIdxByID(int iColumnID)
{
    for (int iRowIdx = 0; iRowIdx < static_cast<int>(m_vecupColumns.size()); ++iRowIdx)
    {
        const ColumnModel* pColumn = m_vecupColumns[iRowIdx].get();
        if (pColumn && pColumn->GetID() == iColumnID)
        {
            return iRowIdx;
        }
    }
    return -1; // Not found
}
bool TableModel::RenameRelationBasedColumn(int iRelationID, const QString& sNewName)
{
    if(RenameColumn(GetColumnRowIdxByRelationID(iRelationID), sNewName))
    {
        return true;
    }
    else
    {
        qWarning("Attempted to rename a ColumnModel with a name that does not exist.");
        return false;
    }
}
void TableModel::OnCreateNewColumnRequested(const QString& sName, const QString& sType, bool blNotNull, bool blIsPrimaryKey, bool blAutoIncrement, bool blUnique)
{
    const bool blIsRelationSource = false;
    AddColumn(std::make_unique<ColumnModel>(m_uiNextColumnID++,
                                            sName,
                                            sType,
                                            blNotNull,
                                            blIsPrimaryKey,
                                            blAutoIncrement,
                                            blUnique,
                                            blIsRelationSource));
}
void TableModel::OnDeleteColumnRequested(int iDeletedColumnID)
{
    if(!RemoveColumn(GetColumnRowIdxByID(iDeletedColumnID)))
    {
        qWarning() << "TableModel::OnDeleteColumnRequested Column could not be deleted, ID = " << iDeletedColumnID;
    }
}
void TableModel::OnReorderColumnRequested(int iFromColumnID, int iToColumnID)
{
    
}