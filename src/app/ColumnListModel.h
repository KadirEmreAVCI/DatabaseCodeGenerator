#ifndef COLUMNLISTMODEL_H_
#define COLUMNLISTMODEL_H_

#include <QAbstractListModel>


#include <vector>
#include <memory>

class ColumnModel;

class ColumnListModel : public QAbstractListModel{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        TypeRole = Qt::UserRole + 1,
        IsEnabledRole,
        IsPrimaryKeyRole,
        IsRelationSourceRole,
        NameRole
    };
    explicit ColumnListModel(QObject *parent = nullptr);
    virtual ~ColumnListModel() override = default;
    
    // ---------- QAbstractListModel interface ----------
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    void AddColumn(std::shared_ptr<ColumnModel> spColumnItem);
    void AddRelationBasedColumn(std::shared_ptr<ColumnModel> spColumnItem);
    bool RemoveColumn(int iRow);
    bool RemoveColumn(const QString& sColumnName);
    int GetColumnIdxByName(const QString& sColumnName) const;
private:
    bool IsRowIndexValid(int iRow) const;
    std::vector<std::shared_ptr<ColumnModel>> m_vecspColumns;
public slots:
    QVariantMap GetColumn(int row) const;
signals:
    void countChanged();
};


#endif // COLUMNLISTMODEL_H_