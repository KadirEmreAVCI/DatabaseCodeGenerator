#ifndef TABLEMODEL_H_
#define TABLEMODEL_H_

#include "Model.h"

class TableModel : public Model{
    Q_OBJECT
public:
    TableModel(const QString& sName, const Position& rPosition, QObject *parent = nullptr);
    virtual ~TableModel()override = default;
};

#endif // TABLEMODEL_H_