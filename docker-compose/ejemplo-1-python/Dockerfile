FROM python:2.7

WORKDIR /usr/src/app/

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

COPY app.py /usr/src/app/

COPY templates /usr/src/app/templates

CMD ["python", "-u", "app.py"]