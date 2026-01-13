#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include <QPointF>
#include <map>

#include "Model.h"

class ColumnModel;
class RelationModel;

enum class RelationRole{
    eOutgoing,
    eIncoming
};

class TableModel : public Model{
    Q_OBJECT
    Q_PROPERTY(QString name READ GetName NOTIFY nameChanged)
    Q_PROPERTY(QPointF point READ GetPointF NOTIFY pointChanged)
    Q_PROPERTY(qreal width READ GetWidth NOTIFY widthChanged)
    Q_PROPERTY(qreal height READ GetHeight NOTIFY heightChanged)
    Q_PROPERTY(QList<QObject*> columns READ GetColumnList NOTIFY columnsChanged)
public:
    TableModel(int iID, const QString& sName = "", const QPointF& rPointF = {}, qreal rWidth = 300, qreal rHeight = 200, QObject *parent = nullptr);
    virtual ~TableModel() override = default;
    void Attach(const RelationModel*, RelationRole);
    void Detach(const RelationModel*, RelationRole);
    int GetColumnRowIdxByRelationID(int iRelationID)const;
    bool RenameRelationBasedColumn(int iRelationID, const QString& sNewRelationBasedColumnName);
    void OnCreateNewColumnRequested(const QString& sName, const QString& sType, bool blNotNull, bool blIsPrimaryKey, bool blAutoIncrement, bool blUnique);
    void OnDeleteColumnRequested(int iDeletedColumnID);
    void OnReorderColumnRequested(int iFromColumnID, int iToColumnID);

    // Getters
    QString GetName() const;
    QPointF GetPointF()const;
    qreal GetWidth()const;
    qreal GetHeight()const;
    QList<QObject*> GetColumnList() const;

    // Setters
    void SetName(const QString &sName);
    void SetPoint(const QPointF&);
    void SetWidth(qreal);
    void SetHeight(qreal);
private:
    void AddColumn(std::unique_ptr<ColumnModel> upColumn);
    bool RemoveColumn(int iRow);
    bool RenameColumn(int iRow, const QString& sNewName);
    bool IsRowIndexValid(int iRow) const;
    void AddRelationBasedColumn(int iRelationID, const QString& sRelationBasedColumnName);
    bool RemoveRelationBasedColumn(int iRelationID);
    int GetColumnRowIdxByID(int iColumnID);

    QString m_sName;
    QPointF m_rPointF;
    qreal m_rWidth;
    qreal m_rHeight;
    unsigned int m_uiNextColumnID = 0;
    std::vector<std::unique_ptr<ColumnModel>> m_vecupColumns;
    std::vector<const RelationModel*> m_vecOutgoingRelations;
    std::vector<const RelationModel*> m_vecIncomingRelations; 
signals:
    void nameChanged();
    void pointChanged();
    void widthChanged();
    void heightChanged();
    void columnsChanged();
};

#endif // TABLEMODEL_H_