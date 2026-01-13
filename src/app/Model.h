#ifndef MODEL_H_
#define MODEL_H_

#include <QObject>

class Model : public QObject {
    Q_OBJECT
    Q_PROPERTY(int ID READ GetID NOTIFY idChanged)
public:
    explicit Model(int iID, QObject *parent = nullptr);
    virtual ~Model() = default;     
    // Getters
    int GetID() const;
    // Setters
    void SetID(int);
protected:
    int m_iID;
signals:
    void idChanged();
};

#endif // MODEL_H_