#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include <QPoint>
#include "Model.h"
#include "ColumnListModel.h"

class TableModel : public Model{
    Q_OBJECT
    Q_PROPERTY(int ID READ GetID NOTIFY idChanged)
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)
    Q_PROPERTY(QPoint point READ GetPoint NOTIFY pointChanged)
    Q_PROPERTY(ColumnListModel* columnListModel READ GetColumnListModel CONSTANT)
public:
    TableModel(const QString& sName, const QPoint& rPoint = {}, QObject *parent = nullptr);
    virtual ~TableModel()override = default;

    // Getters
    int GetID() const;
    QString GetName() const;
    QPoint GetPoint()const;
    ColumnListModel* GetColumnListModel() const;

    // Setters
    void SetID(int);
    void SetName(const QString &name);
    void SetPoint(const QPoint&);
    void SetColumnListModel(ColumnListModel* pColumnListModel);
private:
    int m_iID;
    QString m_sName;
    QPoint m_rPoint;
    ColumnListModel* m_pColumnListModel;
signals:
    void idChanged();
    void nameChanged();
    void pointChanged();
};

#endif // TABLEMODEL_H_