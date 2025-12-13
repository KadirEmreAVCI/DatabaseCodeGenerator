#include "RelationListModel.h"
#include <QVariantMap>

RelationListModel::RelationListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int RelationListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_vecRelationModels.size();
}

QVariant RelationListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return QVariant();

    int row = index.row();
    if (row < 0 || row >= m_vecRelationModels.size())
        return QVariant();

    RelationModel *rel = m_vecRelationModels.at(row);
    if (!rel)
        return QVariant();

    switch (role) {
    case TypeRole:
        return QString(); // or "FK", etc.
    case DestinationRowIdxRole:
        return rel->GetDestinationRowIdx();
    case DestinationTableIDRole:
        return rel->GetDestinationTableID();
    case SourceRowIdxRole:
        return rel->GetSourceRowIdx();
    case RelationshipRole:
        return rel->GetRelationship();
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> RelationListModel::roleNames() const
{
    QHash<int, QByteArray> names;
    names[TypeRole]              = "type";
    names[DestinationRowIdxRole] = "destinationRowIdx";
    names[DestinationTableIDRole]= "destinationTableID";
    names[SourceRowIdxRole]      = "sourceRowIdx";
    names[RelationshipRole]      = "relationship";
    return names;
}

void RelationListModel::AddRelation(RelationModel *pRelationItem)
{
    if (!pRelationItem)
        return;

    const int pos = m_vecRelationModels.size();
    beginInsertRows(QModelIndex(), pos, pos);
    m_vecRelationModels.push_back(pRelationItem);
    pRelationItem->setParent(this);
    endInsertRows();

    emit countChanged();
}

QVariantMap RelationListModel::GetRelation(int row) const
{
    QVariantMap map;

    if (row < 0 || row >= m_vecRelationModels.size())
        return map;

    RelationModel *rel = m_vecRelationModels.at(row);
    if (!rel)
        return map;

    map["destinationRowIdx"] = rel->GetDestinationRowIdx();
    map["destinationTableID"] = rel->GetDestinationTableID();
    map["sourceRowIdx"] = rel->GetSourceRowIdx();
    map["relationship"] = rel->GetRelationship();

    return map;
}
