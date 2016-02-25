CREATE INDEX django_session_expire_date_idx ON admin.django_session(expire_date);

CREATE INDEX django_session_session_key_idx ON admin.django_session(session_key varchar_pattern_ops);

CREATE INDEX remora_sauuser_email_idx ON admin.remora_sauuser(email varchar_pattern_ops);
