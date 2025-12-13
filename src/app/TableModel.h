#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include <QPoint>
#include "Model.h"
#include "ColumnListModel.h"
#include "RelationListModel.h"

class TableModel : public Model{
    Q_OBJECT
    Q_PROPERTY(int ID READ GetID NOTIFY idChanged)
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)
    Q_PROPERTY(QPoint point READ GetPoint NOTIFY pointChanged)
    Q_PROPERTY(qreal width READ GetWidth NOTIFY widthChanged)
    Q_PROPERTY(qreal height READ GetHeight NOTIFY heightChanged)
    Q_PROPERTY(ColumnListModel* columnListModel READ GetColumnListModel CONSTANT)
    Q_PROPERTY(RelationListModel* relationListModel READ GetRelationListModel CONSTANT)
public:
    TableModel(QObject *parent = nullptr, const QString& sName = "", const QPoint& rPoint = {}, qreal rWidth = 300, qreal rHeight = 200);
    virtual ~TableModel()override = default;

    // Getters
    int GetID() const;
    QString GetName() const;
    QPoint GetPoint()const;
    qreal GetWidth()const;
    qreal GetHeight()const;
    ColumnListModel* GetColumnListModel() const;
    RelationListModel* GetRelationListModel() const;

    // Setters
    void SetID(int);
    void SetName(const QString &name);
    void SetPoint(const QPoint&);
    void SetWidth(qreal);
    void SetHeight(qreal);
    void SetColumnListModel(ColumnListModel* pColumnListModel);
    void SetRelationListModel(RelationListModel* pRelationListModel);
private:
    int m_iID;
    QString m_sName;
    QPoint m_rPoint;
    qreal m_rWidth;
    qreal m_rHeight;
    ColumnListModel* m_pColumnListModel;
    RelationListModel* m_pRelationListModel;
signals:
    void idChanged();
    void nameChanged();
    void pointChanged();
    void widthChanged();
    void heightChanged();
};

#endif // TABLEMODEL_H_