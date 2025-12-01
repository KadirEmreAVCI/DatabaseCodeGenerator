#include "TableModel.h"

TableModel::TableModel(QObject *parent, const QString& sName, const QPoint& rPoint, qreal rWidth, qreal rHeight) 
    : Model(parent), m_sName{sName}, m_rPoint{rPoint}, m_rWidth{rWidth}, m_rHeight{rHeight}, m_pColumnListModel{new ColumnListModel(this)}
{
}
int TableModel::GetID() const
{
    return m_iID;
}
QString TableModel::GetName() const
{
    return m_sName;
}
QPoint TableModel::GetPoint()const
{
    return m_rPoint;
}
qreal TableModel::GetWidth()const
{
    return m_rWidth;
}
qreal TableModel::GetHeight()const
{
    return m_rHeight;
}
ColumnListModel* TableModel::GetColumnListModel() const
{
    return m_pColumnListModel;
}
void TableModel::SetColumnListModel(ColumnListModel* pColumnListModel)
{
    m_pColumnListModel = pColumnListModel;
}
void TableModel::SetID(int iID)
{
    if(m_iID != iID)
    {
        m_iID = iID;
        emit idChanged();
    }
}
void TableModel::SetName(const QString &name)
{
    if(m_sName != name)
    {
        m_sName = name;
        emit nameChanged();
    }
}
void TableModel::SetPoint(const QPoint& rPoint)
{
    if(m_rPoint != rPoint)
    {
        m_rPoint = rPoint;
        emit pointChanged();
    }
}
void TableModel::SetWidth(qreal rWidth)
{
    m_rWidth = rWidth;
}
void TableModel::SetHeight(qreal rHeight)
{
    m_rHeight = rHeight;
}