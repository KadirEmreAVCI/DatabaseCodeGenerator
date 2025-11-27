#ifndef MODEL_H_
#define MODEL_H_

#include <QObject>

class Model : public QObject {
    Q_OBJECT
    Q_PROPERTY(int ID READ GetID)
public:
    explicit Model(int iID = -1, QObject *parent = nullptr);
    virtual ~Model() = default; 

    // Getters
    int GetID() const;
protected:
    int m_iID;
};

#endif // MODEL_H_