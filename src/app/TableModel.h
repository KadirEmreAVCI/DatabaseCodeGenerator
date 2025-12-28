#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include <QPointF>
#include <map>

#include "Model.h"

class ColumnModel;
class ColumnListModel;
class RelationModel;

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
    virtual ~TableModel() override;
    void AddColumn(std::shared_ptr<ColumnModel> spColumn);
    bool AddRelation(std::shared_ptr<TableModel> spSourceTable, std::shared_ptr<const TableModel> spDestinationTable);
    bool RemoveRelation(int iDeletedTableID);
    void TableDeleteRequested(int iDeletedTableID);
    std::map<int, std::shared_ptr<RelationModel>> GetRelations() const;

    // Getters
    int GetID() const;
    QString GetName() const;
    QPointF GetPointF()const;
    qreal GetWidth()const;
    qreal GetHeight()const;
    ColumnListModel* GetColumnListModel() const;

    // Setters
    void SetID(int);
    void SetName(const QString &sName);
    void SetPoint(const QPointF&);
    void SetWidth(qreal);
    void SetHeight(qreal);
private:
    void AddRelationBasedColumn(const QString& sDestinationTableName);
    bool DeleteRelationBasedColumn(const QString& sDestinationTableName);
    void UpdateRemainingRelations();

    int m_iID;
    QString m_sName;
    QPointF m_rPointF;
    qreal m_rWidth;
    qreal m_rHeight;
    ColumnListModel* m_pColumnListModel;
    
    static int ms_iNextRelationID;
    std::map<int, std::shared_ptr<RelationModel>> m_mapspRelations;
signals:
    void idChanged();
    void nameChanged();
    void pointChanged();
    void widthChanged();
    void heightChanged();
};

#endif // TABLEMODEL_H_