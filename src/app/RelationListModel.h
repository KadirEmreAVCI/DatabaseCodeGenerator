#ifndef RELATIONLISTMODEL_H_
#define RELATIONLISTMODEL_H_

#include <QAbstractListModel>
#include "RelationModel.h"

class RelationListModel : public QAbstractListModel{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        TypeRole = Qt::UserRole + 1,
        DestinationRowIdxRole,
        DestinationTableIDRole,
        SourceRowIdxRole,
        RelationshipRole
    };
    explicit RelationListModel(QObject *parent = nullptr);
    virtual ~RelationListModel() override = default;
    
    // ---------- QAbstractListModel interface ----------
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    void AddRelation(RelationModel* pRelationItem);
private:
    QVector<RelationModel*> m_vecRelationModels;
public slots:
    QVariantMap GetRelation(int row) const;
signals:
    void countChanged();
};


#endif // RELATIONLISTMODEL_H_