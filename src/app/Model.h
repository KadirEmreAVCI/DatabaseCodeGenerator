#ifndef MODEL_H_
#define MODEL_H_

#include <QObject>

class Model : public QObject {
    Q_OBJECT
    
public:
    explicit Model(QObject *parent = nullptr);
    virtual ~Model() = default;         
};

#endif // MODEL_H_