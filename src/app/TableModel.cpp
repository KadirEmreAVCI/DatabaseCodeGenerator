#include "TableModel.h"
#include "ColumnListModel.h"

TableModel::TableModel(QObject *parent, const QString& sName, const QPointF& rPointF, qreal rWidth, qreal rHeight) 
    : Model(parent), m_sName{sName}, m_rPointF{rPointF}, m_rWidth{rWidth}, m_rHeight{rHeight}, m_pColumnListModel{new ColumnListModel(this)}
{
}
void TableModel::AddColumn(std::shared_ptr<ColumnModel> spColumn)
{
    if (m_pColumnListModel != nullptr)
    {
        m_pColumnListModel->AddColumn(spColumn);
    }
}
int TableModel::GetID() const
{
    return m_iID;
}
QString TableModel::GetName() const
{
    return m_sName;
}
QPointF TableModel::GetPointF()const
{
    return m_rPointF;
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
void TableModel::SetPoint(const QPointF& rPointF)
{
    if(m_rPointF != rPointF)
    {
        m_rPointF = rPointF;
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
void TableModel::SetColumnListModel(ColumnListModel* pColumnListModel)
{
    m_pColumnListModel = pColumnListModel;
}