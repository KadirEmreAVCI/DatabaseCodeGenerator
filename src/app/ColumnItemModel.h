#ifndef COLUMNITEMMODEL_H_
#define COLUMNITEMMODEL_H_

#include "Model.h"

class ColumnItemModel : public Model{
    Q_OBJECT
    Q_PROPERTY(QString type READ GetType NOTIFY typeChanged)
    Q_PROPERTY(bool isEnabled READ GetIsEnabled NOTIFY isEnabledChanged)
    Q_PROPERTY(bool isPrimaryKey READ GetIsPrimaryKey NOTIFY isPrimaryKeyChanged)
    Q_PROPERTY(bool isRelationSource READ GetIsRelationSource NOTIFY isRelationSourceChanged)
public:
    ColumnItemModel(const QString& sType, bool blIsEnabled, bool blIsPrimaryKey, bool blIsRelationSource, const Position& rPosition = {}, const QString& sName = "", QObject *parent = nullptr);
    virtual ~ColumnItemModel()override = default;

    // Getters and Setters
    QString GetType() const;
    bool GetIsEnabled() const;
    bool GetIsPrimaryKey() const;
    bool GetIsRelationSource() const;

    void SetType(const QString& sType);
    void SetIsEnabled(bool blEnabled);
    void SetIsPrimaryKey(bool blPrimaryKey);
    void SetIsRelationSource(bool blRelationSource);
signals:
    void typeChanged();
    void isEnabledChanged();
    void isPrimaryKeyChanged();
    void isRelationSourceChanged();
private:
    QString m_sType;
    bool m_blIsEnabled{false};
    bool m_blIsPrimaryKey{false};
    bool m_blIsRelationSource{false};
};
#endif // COLUMNITEMMODEL_H_