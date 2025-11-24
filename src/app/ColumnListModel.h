#ifndef COLUMNLISTMODEL_H_
#define COLUMNLISTMODEL_H_

#include <QAbstractListModel>
#include "ColumnItemModel.h"

class ColumnListModel : public QAbstractListModel{
    Q_OBJECT
public:
    enum Roles {
        TypeRole = Qt::UserRole + 1,
        IsEnabledRole,
        IsPrimaryKeyRole,
        IsRelationSourceRole,
        NameRole,
        XRole,
        YRole
    };
    explicit ColumnListModel(QObject *parent = nullptr);
    virtual ~ColumnListModel() override = default;
    
    // ---------- QAbstractListModel interface ----------
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

private:
    QVector<ColumnItemModel*> m_vecColumnItems;
};


#endif // COLUMNLISTMODEL_H_