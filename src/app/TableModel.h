#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include <QPointF>
#include "Model.h"

class ColumnModel;
class ColumnListModel;

class TableModel : public Model{
    Q_OBJECT
    Q_PROPERTY(int ID READ GetID NOTIFY idChanged)
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)
    Q_PROPERTY(QPointF point READ GetPointF NOTIFY pointChanged)
    Q_PROPERTY(qreal width READ GetWidth NOTIFY widthChanged)
    Q_PROPERTY(qreal height READ GetHeight NOTIFY heightChanged)
    Q_PROPERTY(ColumnListModel* columnListModel READ GetColumnListModel CONSTANT)
public:
    TableModel(QObject *parent = nullptr, const QString& sName = "", const QPointF& rPointF = {}, qreal rWidth = 300, qreal rHeight = 200);
    virtual ~TableModel()override = default;
    void AddColumn(std::shared_ptr<ColumnModel> spColumn);

    // Getters
    int GetID() const;
    QString GetName() const;
    QPointF GetPointF()const;
    qreal GetWidth()const;
    qreal GetHeight()const;
    ColumnListModel* GetColumnListModel() const;

    // Setters
    void SetID(int);
    void SetName(const QString &name);
    void SetPoint(const QPointF&);
    void SetWidth(qreal);
    void SetHeight(qreal);
    void SetColumnListModel(ColumnListModel* pColumnListModel);
private:
    int m_iID;
    QString m_sName;
    QPointF m_rPointF;
    qreal m_rWidth;
    qreal m_rHeight;
    ColumnListModel* m_pColumnListModel;
signals:
    void idChanged();
    void nameChanged();
    void pointChanged();
    void widthChanged();
    void heightChanged();
};

#endif // TABLEMODEL_H_