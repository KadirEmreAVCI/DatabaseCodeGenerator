#ifndef COLUMNLISTMODEL_H_
#define COLUMNLISTMODEL_H_

#include <QAbstractListModel>
#include "ColumnModel.h"

class ColumnListModel : public QAbstractListModel{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

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
    ColumnListModel(const QVector<ColumnModel*>& vecColumnItems, QObject *parent = nullptr);
    virtual ~ColumnListModel() override = default;
    
    // ---------- QAbstractListModel interface ----------
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    void AddColumnItem(ColumnModel* pColumnItem);

    Q_INVOKABLE QVariantMap get(int row) const;
private:
    QVector<ColumnModel*> m_vecColumnModels;
signals:
    void countChanged();
};


#endif // COLUMNLISTMODEL_H_